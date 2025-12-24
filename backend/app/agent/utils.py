import os
import re
from typing import List, Any, Dict
from IPython.display import Image, display
from langchain.chat_models import init_chat_model
from langchain_core.language_models import BaseChatModel
from app.logger import get_logger

logger = get_logger(__name__)


def parse_inf_file(inf_path: str) -> List[str]:
    """
    Parse a PSCAD .inf file and extract column descriptions.

    Args:
        inf_path (str): Path to the .inf file

    Returns:
        List[str]: List of column descriptions in order
    """
    logger.info("Entering parse_inf_file")
    column_names = []
    pgb_pattern = re.compile(r'PGB\(\d+\)\s+Output\s+Desc="([^"]+)"')

    try:
        with open(inf_path, "r") as f:
            for line in f:
                match = pgb_pattern.search(line)
                if match:
                    column_names.append(match.group(1))
    except Exception as e:
        print(f"Error parsing .inf file {inf_path}: {e}")

    return column_names


def save_graph_diagram(graph, filename="graph.png"):
    """
    Generate and save a graph of the given graph.

    Args:
        graph: The graph to be depicted.
        filename: The name of the file to save the graph as.
    """
    logger.info("Entering save_graph_diagram")
    try:
        graph = graph.get_graph(xray=True).draw_mermaid_png()
        with open(filename, "wb") as f:
            f.write(graph)
        display(Image(filename))
    except Exception as e:
        print(f"An error occurred while generating the graph: {e}")


def print_stream(stream):
    logger.info("Entering print_stream")
    for s in stream:
        message = s["messages"][-1]
        if isinstance(message, tuple):
            print(message)
        else:
            message.pretty_print()


# def load_chat_model(fully_specified_name: str) -> BaseChatModel:
def load_chat_model(model_name: str, model_kwargs: dict | None = None) -> Any:
    """
    Load a chat model based on MODEL_PROVIDER env var.
    Supported providers: 'bedrock' and 'openai' (default).

    - For 'bedrock' we attempt to import a Bedrock chat model from langchain.
      If the Bedrock class is not available, raise with guidance.
    - For 'openai' we ensure OPENAI_API_KEY is set before constructing the client.
    """
    logger.info(f"Entering load_chat_model: {model_name}")
    model_kwargs = model_kwargs or {}
    provider = os.environ.get("MODEL_PROVIDER", "bedrock").lower()
    #model_name = "anthropic.claude-3-sonnet-20240229-v1:0"
    if provider == "bedrock":
        try:
            # Try the Bedrock chat model import; adjust import path if your langchain version differs
            # from langchain.chat_models import Bedrock  # type: ignore
            # from langchain_community.chat_models import Bedrock
            # from la   ngchain_aws import ChatBedrock
            from langchain_aws import ChatBedrockConverse
        except Exception as e:
            msg = (
                "Bedrock chat model class not available. "
                "Install LangChain with Bedrock support or update imports. "
                "Example: pip install 'langchain[aws]' and verify your langchain version."
            )
            logger.exception(msg)
            raise RuntimeError(msg) from e

        aws_region = os.environ.get("AWS_REGION", "us-east-1")
        aws_key = os.environ.get("AWS_ACCESS_KEY_ID")
        aws_secret = os.environ.get("AWS_SECRET_ACCESS_KEY")

        if not (aws_key and aws_secret):
            logger.warning("AWS credentials not set in environment; Bedrock client may fail.")
        # Instantiate Bedrock model; adjust constructor args for your langchain version
        try:
            return ChatBedrockConverse(region_name=aws_region, client_kwargs={
                "aws_access_key_id": aws_key,
                "aws_secret_access_key": aws_secret,
            }, model_id=model_name, **model_kwargs)
        except TypeError:
            # Fallback: some LangChain versions use different param names
            return Bedrock(model_id=model_name, region_name=aws_region, **model_kwargs)

    # default: openai
    try:
        from langchain.chat_models import ChatOpenAI  # type: ignore
    except Exception as e:
        msg = "Failed to import ChatOpenAI. Ensure langchain OpenAI integration is installed."
        logger.exception(msg)
        raise RuntimeError(msg) from e

    openai_key = os.environ.get("OPENAI_API_KEY")
    if not openai_key:
        msg = (
            "OPENAI_API_KEY is not set. Set OPENAI_API_KEY or switch to Bedrock by setting "
            "MODEL_PROVIDER=bedrock and providing AWS credentials."
        )
        logger.error(msg)
        raise RuntimeError(msg)

    # instantiate ChatOpenAI; param names may vary by langchain version
    try:
        return ChatOpenAI(model_name=model_name, openai_api_key=openai_key, **model_kwargs)
    except TypeError:
        # alternate constructor signature
        return ChatOpenAI(model=model_name, openai_api_key=openai_key, **model_kwargs)

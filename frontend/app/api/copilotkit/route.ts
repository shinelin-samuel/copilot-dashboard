import { NextRequest } from "next/server";
import {
  CopilotRuntime,
  LangChainAdapter,
  copilotRuntimeNextJSAppRouterEndpoint,
} from "@copilotkit/runtime";
import { ChatBedrockConverse } from "@langchain/aws";

// Initialize the LangChain Bedrock model
const model = new ChatBedrockConverse({
  region: process.env.AWS_REGION || "us-east-1",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  },
  model: "anthropic.claude-3-sonnet-20240229-v1:0",
});

// Create the LangChain Adapter
const serviceAdapter = new LangChainAdapter({
  chainFn: async ({ messages, tools }: { messages: any; tools: any }) => {
    // Fix: AWS Bedrock throws a ValidationException if a message content is empty.
    // We sanitize the messages to ensure empty content is replaced with a space.
    const sanitizedMessages = messages.map((m: any) => {
      // If content is empty and there are no tool calls (which would otherwise populate the content block),
      // replace it with a single space to satisfy Bedrock's validation.
      if (m.content === "" && (!m.tool_calls || m.tool_calls.length === 0)) {
        m.content = " ";
      }
      return m;
    });

    // Pass messages and tools to the model and stream the response
    return model.stream(sanitizedMessages, { tools });
  },
});

const runtime = new CopilotRuntime({
  remoteEndpoints: [
    {
      url: `${process.env.SERVER_API_URL}/copilotkit`,
    },
  ],
});

export const POST = async (req: NextRequest) => {
  const { handleRequest } = copilotRuntimeNextJSAppRouterEndpoint({
    runtime,
    serviceAdapter,
    endpoint: "/api/copilotkit",
  });

  return handleRequest(req);
};

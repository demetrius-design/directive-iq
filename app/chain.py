import os
from langchain.chat_models import AzureChatOpenAI
from langchain.agents import initialize_agent, Tool
from langchain.memory import ConversationBufferMemory

from tools.validator import validate_schema_function
from tools.bicep_gen import generate_bicep_code

# Load environment variables (recommended for local dev)
AZURE_OPENAI_DEPLOYMENT = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-4-deployment")
AZURE_OPENAI_API_KEY = os.getenv("AZURE_OPENAI_API_KEY")
AZURE_OPENAI_ENDPOINT = os.getenv("AZURE_OPENAI_ENDPOINT", "https://your-resource-name.openai.azure.com/")
AZURE_OPENAI_VERSION = os.getenv("AZURE_OPENAI_VERSION", "2023-07-01-preview")

# Initialize Azure OpenAI LLM
llm = AzureChatOpenAI(
    deployment_name=AZURE_OPENAI_DEPLOYMENT,
    openai_api_key=AZURE_OPENAI_API_KEY,
    openai_api_base=AZURE_OPENAI_ENDPOINT,
    openai_api_version=AZURE_OPENAI_VERSION,
    temperature=0.3
)

# Optional memory to maintain conversation context
memory = ConversationBufferMemory(memory_key="chat_history", return_messages=True)

# Define available LangChain tools for DirectiveIQ
tools = [
    Tool(
        name="SchemaValidator",
        func=validate_schema_function,
        description="Validates infrastructure logic before Bicep generation."
    ),
    Tool(
        name="BicepGenerator",
        func=generate_bicep_code,
        description="Generates deployable Azure Bicep templates from natural language."
    )
]

# Initialize agent with tools and memory
agent = initialize_agent(
    tools=tools,
    llm=llm,
    memory=memory,
    agent_type="chat-zero-shot-react-description",
    verbose=True
)

def run_orchestration(prompt: str) -> str:
    """
    Runs the main DirectiveIQ orchestration logic using LangChain's agent.
    Accepts a natural language prompt and routes to appropriate tools.
    """
    try:
        return agent.run(prompt)
    except Exception as e:
        return f"DirectiveIQ encountered an error: {str(e)}"

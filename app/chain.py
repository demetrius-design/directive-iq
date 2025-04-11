from langchain.chat_models import ChatOpenAI
from langchain.agents import initialize_agent, Tool
from langchain.memory import ConversationBufferMemory

from tools.validator import validate_schema_function
from tools.bicep_gen import generate_bicep_code

llm = ChatOpenAI(
    temperature=0.3,
    model_name="gpt-4",  # or gpt-3.5-turbo if needed
)

memory = ConversationBufferMemory()

tools = [
    Tool(
        name="SchemaValidator",
        func=validate_schema_function,
        description="Validates automation logic before Bicep generation."
    ),
    Tool(
        name="BicepGenerator",
        func=generate_bicep_code,
        description="Converts validated logic into Bicep infrastructure code."
    )
]

agent = initialize_agent(
    tools=tools,
    llm=llm,
    memory=memory,
    agent_type="chat-zero-shot-react-description"
)

def run_orchestration(prompt: str) -> str:
    return agent.run(prompt)

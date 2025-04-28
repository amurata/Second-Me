from typing import Optional
import numpy as np
from lpm_kernel.api.dto.user_llm_config_dto import (
    UserLLMConfigDTO,
)
from lpm_kernel.configs.logging import get_train_process_logger
logger = get_train_process_logger()
import requests

def openai_strategy(user_llm_config: Optional[UserLLMConfigDTO], chunked_texts):
    try:
        headers = {
            "Authorization": f"Bearer {user_llm_config.embedding_api_key}",
            "Content-Type": "application/json",
        }

        data = {"input": chunked_texts, "model": user_llm_config.embedding_model_name}

        logger.info(f"Getting embedding for {data}, total chunks: {len(chunked_texts)}")

        response = requests.post(
            f"{user_llm_config.embedding_endpoint}/embeddings", headers=headers, json=data
        )
        
        # 400エラーの詳細をログに出力
        if response.status_code != 200:
            logger.error(f"API Error Response: {response.status_code} - {response.text}")
            
        response.raise_for_status()
        result = response.json()

        # Extract embedding vectors
        embeddings = [item["embedding"] for item in result["data"]]
        embeddings_array = np.array(embeddings)

        return embeddings_array

    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to get embeddings: {str(e)}", exc_info=True)
        raise Exception(f"Failed to get embeddings: {str(e)}")


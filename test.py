"""Interactive multi-turn chat client for a local llama-server instance."""
 
import time
 
import httpx
 
SERVER_URL = "http://127.0.0.1:8080/v1/chat/completions"
 
SYSTEM_PROMPT = (
    "你是一个简洁的助手。直接回答问题本身，不要输出额外的背景介绍、"
    "铺垫或总结性套话，也不要主动展开与问题无关的补充说明。"
    "除非用户明确要求详细解释，否则用最少的文字给出准确答案。"
)
 
 
def stream_reply(messages: list[dict]) -> str:
    payload = {
        "messages": messages,
        "stream": True,
        "temperature": 0.7,
    }
    reply = ""
    with httpx.stream("POST", SERVER_URL, json=payload, timeout=None) as resp:
        resp.raise_for_status()
        for line in resp.iter_lines():
            if not line.startswith("data: "):
                continue
            data = line[len("data: "):]
            if data == "[DONE]":
                break
            chunk = httpx.Response(200, content=data).json()
            delta = chunk["choices"][0]["delta"].get("content", "")
            if delta:
                print(delta, end="", flush=True)
                reply += delta
    print()
    return reply
 
 
def main():
    messages: list[dict] = [{"role": "system", "content": SYSTEM_PROMPT}]
    print("多轮对话测试，输入 exit 退出\n")
    while True:
        user_input = input("你: ").strip()
        if user_input.lower() in ("exit", "quit"):
            break
        if not user_input:
            continue
        messages.append({"role": "user", "content": user_input})
        print("助手: ", end="", flush=True)
        start = time.perf_counter()
        reply = stream_reply(messages)
        elapsed = time.perf_counter() - start
        print(f"[耗时 {elapsed:.2f}s]")
        messages.append({"role": "assistant", "content": reply})
 
 
if __name__ == "__main__":
    main()
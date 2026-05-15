import pickle
import json
import time
from difflib import get_close_matches

with open('zumzum','rb') as file:
    j = pickle.load(file)
    i= "".join(str(items) for items in j)

def load_knowledge_base(file_path: str) -> dict:
    with open(file_path, 'r') as file:
        data: dict = json.load(file)
    return data

def save_knowledge_base(file_path : str, data: dict):
    with open(file_path, 'w') as file:
        json.dump(data, file, indent=2)
        
def find_best_match(user_questions: str, questions: list[str]) -> str or None:
    matches: list = get_close_matches(user_questions, questions, n=1, cutoff=0.6)
    return matches[0] if matches else None

def get_answer_for_question(question: str, knowledge_base: dict) -> str or None:
    for q in knowledge_base["questions"]:
        if q["question"] == question:
            return q["answer"]

def abot():
    knowledge_base: dict = load_knowledge_base('knowledge.json')
    a=1
    while a:
        user_input: str = i
        if user_input.lower() == 'quit':
            break 
        best_match: str | None = find_best_match(user_input, [q["question"] for q in knowledge_base["questions"]])
        if best_match:
            answer: str = get_answer_for_question(best_match, knowledge_base)
            print(f'BOT: {answer}')
        else:
            print('BOT: tell me')
            new_answer: str = input('Type the answer or "skip" to skip: ')
            
            if new_answer.lower() != 'skip':
                knowledge_base["questions"].append({"question": user_input, "answer": new_answer})
                save_knowledge_base('knowledge.json', knowledge_base)
                print('ty')
        a=0
if __name__ == '__main__':
    abot()
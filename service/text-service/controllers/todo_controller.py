from fastapi import APIRouter, HTTPException
from models.Todo import Todo

router = APIRouter()

@router.get("/todos")
async def get_todos():
    return [{"id": 1, "task": "Sample Todo", "completed": False}]

@router.post("/todos")
async def create_todo(todo: Todo):
    if not todo.task:
        raise HTTPException(status_code=400, detail="Task is required")
    return {"id": 2, "task": todo.task, "completed": todo.completed}

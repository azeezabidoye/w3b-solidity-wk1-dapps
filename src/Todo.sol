// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Todo {
    struct Task {
        uint8 id;
        string title;
        bool isComplete;
        uint256 timeCompleted;
    }

    Task[] public tasks;
    uint8 todo_id;

    function createTask(string memory _title) public {
        todo_id = todo_id + 1;
        Task memory task = Task({
            id: todo_id,
            title: _title,
            isComplete: false,
            timeCompleted: 0
        });
        tasks.push(task);
    }

    function getAllTasks() external view returns (Task[] memory) {
        return tasks;
    }

    function markComplete(uint8 _id) external {
        for (uint8 i; i < tasks.length; i++) {
            if (tasks[i].id == _id) {
                tasks[i].isComplete = true;
                tasks[i].timeCompleted = block.timestamp;
            }
        }
    }

    function deleteTask(uint8 _id) external {
        for (uint8 i; i < tasks.length; i++) {
            if (tasks[i].id == _id) {
                // tasks[i] = tasks[i + 1];
                tasks[i] = tasks[tasks.length - 1];
                tasks.pop();
            }
        }
    }

    function updateTask(uint8 _id, string memory _title) external {
        for (uint8 i; i < tasks.length; i++) {
            if (!tasks[i].isComplete && tasks[i].id == _id) {
                tasks[i].title = _title;
                break;
            }
        }
    }
}

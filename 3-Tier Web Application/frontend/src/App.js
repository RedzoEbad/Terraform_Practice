import React, { useState, useEffect } from 'react';
import axios from 'axios';
import TodoForm from './components/TodoForm';
import TodoList from './components/TodoList';
import './App.css';

function App() {
  const [todos, setTodos] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const API_URL =
    // process.env.REACT_APP_API_URL ||
    // (process.env.REACT_APP_ALB_DNS_URL && `https://${process.env.REACT_APP_ALB_DNS_URL}`) ||
    'http://localhost:5000';

  // Fetch all todos
  useEffect(() => {
    fetchTodos();
  }, []);

  const fetchTodos = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_URL}/api/todos`);
      setTodos(response.data);
      setError(null);
    } catch (err) {
      setError('Failed to fetch todos');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  // Add todo
  const addTodo = async (todoData) => {
    try {
      const response = await axios.post(`${API_URL}/api/todos`, todoData);
      setTodos([response.data, ...todos]);
      setError(null);
    } catch (err) {
      setError('Failed to add todo');
      console.error(err);
    }
  };

  // Update todo
  const updateTodo = async (id, updatedData) => {
    try {
      const response = await axios.put(`${API_URL}/api/todos/${id}`, updatedData);
      setTodos(todos.map(todo => todo._id === id ? response.data : todo));
      setError(null);
    } catch (err) {
      setError('Failed to update todo');
      console.error(err);
    }
  };

  // Delete todo
  const deleteTodo = async (id) => {
    try {
      await axios.delete(`${API_URL}/api/todos/${id}`);
      setTodos(todos.filter(todo => todo._id !== id));
      setError(null);
    } catch (err) {
      setError('Failed to delete todo');
      console.error(err);
    }
  };

  // Toggle todo completion
  const toggleTodo = (todo) => {
    updateTodo(todo._id, { ...todo, completed: !todo.completed });
  };

  return (
    <div className="app">
      <div className="container">
        <header className="header">
          <h1>My Todo App</h1>
          <p>Keep track of your tasks</p>
        </header>

        {error && <div className="error-message">{error}</div>}

        <TodoForm onAddTodo={addTodo} />

        {loading ? (
          <div className="loading">Loading todos...</div>
        ) : (
          <TodoList
            todos={todos}
            onToggleTodo={toggleTodo}
            onDeleteTodo={deleteTodo}
            onUpdateTodo={updateTodo}
          />
        )}
      </div>
    </div>
  );
}

export default App;

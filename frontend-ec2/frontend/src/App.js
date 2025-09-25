// frontend/src/App.js
import React from "react";
import axios from "axios";
import "./App.scss";
import AddTodo from "./components/AddTodo";
import TodoList from "./components/TodoList";
import logger from "./utils/logger";
import { v4 as uuidv4 } from 'uuid'; // +++ IMPORT THE UNIVERSAL UUID LIBRARY +++

export default class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      todos: [],
      isLoading: true,
      error: null,
    };
    // This initial log has no correlationId as it's a one-off system event.
    logger.info("App: constructor initialized state");
  }

  // MODIFIED: Accepts an optional correlationId. If one isn't provided,
  // it creates a new one using the uuid library.
  fetchAllTodos = (correlationId = uuidv4()) => {
    logger.info("App: Starting to fetch all todos", {}, correlationId);
    this.setState({ isLoading: true, error: null });

    axios
      .get("/api/todos")
      .then((response) => {
        if (response.data && response.data.success && Array.isArray(response.data.data)) {
          const todoCount = response.data.data.length;
          logger.info(`App: Successfully fetched todos`, { count: todoCount }, correlationId);
          this.setState({
            todos: response.data.data,
            isLoading: false,
          });
        } else {
          logger.error("App: API failed to fetch todos or returned unexpected data format", { responseData: response.data }, correlationId);
          this.setState({
            todos: [],
            isLoading: false,
            error: "Could not fetch todos or data format is incorrect.",
          });
        }
      })
      .catch((e) => {
        logger.error("App: Network or server error while fetching todos", { errorMessage: e.message, status: e.response?.status }, correlationId);
        this.setState({
          todos: [],
          isLoading: false,
          error: `Error fetching todos: ${e.message}`,
        });
      });
  };

  componentDidMount() {
    // MODIFIED: Use uuidv4() to create a unique ID for the initial page load process.
    const correlationId = uuidv4();
    logger.info("App: component did mount, triggering initial fetch", {}, correlationId);
    this.fetchAllTodos(correlationId);
  }

  // MODIFIED: This function now defines and manages an entire user process.
  handleAddTodo = (value) => {
    // MODIFIED: Use uuidv4() to create a single, unique ID for this entire "add todo" action.
    const correlationId = uuidv4();

    logger.info("App: Attempting to add a new todo", { todoTextLength: value.length }, correlationId);

    axios
      .post("/api/todos", { text: value })
      .then((response) => {
        if (response.data && response.data.success) {
          logger.info("App: Todo created successfully, re-fetching list", {}, correlationId);
          // Pass the SAME ID down to the next function in the chain.
          this.fetchAllTodos(correlationId);
        } else {
          logger.error("App: API failed to create todo", { responseData: response.data }, correlationId);
          this.setState({
            error: "Failed to create todo. Please try again.",
          });
        }
      })
      .catch((e) => {
        logger.error("App: Network or server error while creating todo", { errorMessage: e.message, status: e.response?.status }, correlationId);
        this.setState({
          error: `Error creating todo: ${e.message}`,
        });
      });
  };

  render() {
    const { todos, isLoading, error } = this.state;

    let content;
    if (isLoading) {
      content = <div className="alert alert-info">Loading todos...</div>;
    } else if (error) {
      content = <div className="alert alert-danger">Error: {error}</div>;
    } else if (todos.length > 0) {
      content = <TodoList todos={todos} />;
    } else {
      content = (
        <div className="alert alert-primary" role="alert">
          No Todos to display. Add one above!
        </div>
      );
    }

    return (
      <div className="App container">
        <div className="container-fluid">
          <div className="row">
            <div className="col-xs-12 col-sm-8 col-md-8 offset-md-2">
              <h1>Todos</h1>
              <div className="todo-app">
                <AddTodo handleAddTodo={this.handleAddTodo} />
                {content}
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

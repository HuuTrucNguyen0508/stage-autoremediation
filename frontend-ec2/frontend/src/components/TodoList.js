// frontend/src/components/TodoList.js
import React from "react";

export default class TodoList extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      activeIndex: null, // Set to null initially or based on first item if needed
    };
    console.log("TodoList.js: constructor, initial props:", props);
    console.log("TodoList.js: constructor, initial state:", this.state);
  }

  // Optional: If you want to reset activeIndex when props change significantly
  // UNSAFE_componentWillReceiveProps(nextProps) {
  //   console.log("TodoList.js: UNSAFE_componentWillReceiveProps, nextProps.todos:", nextProps.todos);
  //   if (nextProps.todos.length > 0 && this.props.todos !== nextProps.todos) {
  //     // Reset activeIndex or set based on new props, e.g. to 0 or null
  //     // this.setState({ activeIndex: 0 });
  //   } else if (nextProps.todos.length === 0) {
  //     this.setState({ activeIndex: null });
  //   }
  // }
  // A better approach for props changes is getDerivedStateFromProps or componentDidUpdate

  handleActive(index) {
    console.log("TodoList.js: handleActive called with index:", index);
    this.setState({
      activeIndex: index,
    });
  }

  renderTodos(todos) {
    console.log("TodoList.js: renderTodos() called with todos:", todos);
    if (!Array.isArray(todos) || todos.length === 0) {
      console.log("TodoList.js: renderTodos() - received no todos or not an array, returning null.");
      return null; // Or some placeholder
    }

    return (
      <ul className="list-group">
        {todos.map((todo, i) => {
          // Check if todo object and todo.text exists
          if (!todo || typeof todo.text === 'undefined') {
            console.warn("TodoList.js: Skipping render for invalid todo object at index", i, ":", todo);
            return null; // Skip rendering this item if it's malformed
          }
          console.log("TodoList.js: renderTodos() - mapping todo:", todo, "at index:", i);
          return (
            <li
              className={
                "list-group-item cursor-pointer " +
                (i === this.state.activeIndex ? "active" : "")
              }
              key={todo._id || i} // Use todo._id if available, fallback to index i
                                   // This is crucial for React's reconciliation
              onClick={() => {
                this.handleActive(i);
              }}
            >
              {todo.text}
            </li>
          );
        })}
      </ul>
    );
  }

  render() {
    console.log("TodoList.js: render() called");
    console.log("TodoList.js render(), this.props.todos:", this.props.todos);

    let { todos } = this.props;

    // Ensure todos is an array before checking its length
    const hasTodos = Array.isArray(todos) && todos.length > 0;
    console.log("TodoList.js render(), hasTodos:", hasTodos);


    return hasTodos ? (
      this.renderTodos(todos)
    ) : (
      <div className="alert alert-primary" role="alert">
        No Todos to display
      </div>
    );
  }
}

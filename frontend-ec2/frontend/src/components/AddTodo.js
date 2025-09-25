import React from "react";
import logger from "../utils/logger"; // +++ IMPORT THE LOGGER

export default class AddTodo extends React.Component {
  handleSubmit = (e) => {
    e.preventDefault();
    const { value } = e.target.elements.value;
    if (value.length > 0) {
      this.props.handleAddTodo(value);
      e.target.reset();
    } else {
      // +++ ADD A VALUABLE LOG FOR USER BEHAVIOR +++
      logger.warn("AddTodo: User attempted to submit an empty todo");
    }
  };

  render() {
    return (
      <form
        noValidate
        onSubmit={this.handleSubmit}
        className="new-todo form-group"
      >
        <input
          type="text"
          name="value"
          required
          minLength={1}
          className="form-control"
          placeholder="What needs to be done?"
        />
        <button className="btn btn-primary" type="submit">
          Add Todo
        </button>
      </form>
    );
  }
}

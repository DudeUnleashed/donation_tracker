import React from 'react';
import './Modal.css';

const Modal = ({ message, onConfirm, onCancel }) => (
  <div className="modal-overlay">
    <div className="modal-content">
      <p>{message}</p>
      <div className="modal-actions">
        <button onClick={onConfirm}>Confirm</button>
        <button onClick={onCancel}>Cancel</button>
      </div>
    </div>
  </div>
);

export default Modal;

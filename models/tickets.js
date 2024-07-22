// models/ticket.js
const mongoose = require('mongoose');

const ticketSchema = new mongoose.Schema({
  ticketId: { type: String, required: true, unique: true },
  ticketUsed: { type: Boolean, default: false }
});

const Ticket = mongoose.model('Ticket', ticketSchema);

module.exports = Ticket;

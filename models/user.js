const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  userMetamaskAdr: {
    type: String,
    unique: true,
    required: true
  },
  userID: {
    type: String,
    unique: true,
    required: true
  },
  userName: {
    type: String,
  },
  userNickname: {
    type: String,
    required: true
  },
  userCity: {
    type: String,
  },
  userEmail: {
    type: String,
  }
}, { collection: 'users' });

const User = mongoose.model('User', userSchema);

module.exports = User;

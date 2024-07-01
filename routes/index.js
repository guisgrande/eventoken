var express = require('express');
var router = express.Router();
const User = require('../models/user');
const { v4: uuidv4 } = require('uuid');

function generateUniqueUserID() {
  return `user-${uuidv4()}`;
}

/* GET Home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Eventoken' });
});

/* GET Account page. */
router.get('/account', function(req, res, next) {
  res.render('account', { title: 'Eventoken - Account', name:null });
});

/* GET Events page. */
router.get('/events', function(req, res, next) {
  res.render('events', { title: 'Eventoken - Events', name:null });
});

/* GET Resale page. */
router.get('/resale', function(req, res, next) {
  res.render('resale', { title: 'Eventoken - Resale Tickets', name:null });
});

/* GET Ticket page. */
router.get('/tickets', function(req, res, next) {
  res.render('tickets', { title: 'Eventoken - My Tickets', name:null });
});

/* GET Manag - Addevent page. */
router.get('/manag/addevent', function(req, res, next) {
  res.render('manag/addevent', { title: 'Eventoken - Create an Event' });
});

/* GET and POST Manag - Adduser page. */
router.get('/manag/adduser', function(req, res, next) {
  res.render('manag/adduser', { title: 'Eventoken - Add User' });
});

router.post('/manag/adduser', async (req, res) => {
  const { userMetamaskAdr, userNickname } = req.body;
  try {
    // Check if the user already exists using the MetaMask address.
    let user = await User.findOne({ userMetamaskAdr });

    if (user) {
      console.log("User already exists");
      res.redirect('/account');
    } else {
      // Generate a unique userID here
      const newUser = await User.create({
        userMetamaskAdr,
        userID: generateUniqueUserID(),
        userNickname,
        userName: 'TestUser',
        userCity: 'Test City',
        userEmail: 'test@example.com'
      });
      console.log("New user created");
      res.redirect('/account');
    }
  } catch (error) {
    if (error.code === 11000) { // MongoDB duplicate key error
      res.status(400).json({ message: 'Duplicate userID, try again.' });
    } else {
      res.status(400).json({ message: error.message });
    }
  }
});

/* GET Manag - Addevent page. */
router.get('/manag/addevent', function(req, res, next) {
  res.render('manag/addevent', { title: 'Eventoken - Create Event' });
});

module.exports = router;

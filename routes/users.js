var express = require('express');
var router = express.Router();
const User = require('../models/user');

/* GET users listing. */
router.get('/', async (req, res) => {
  const { userMetamaskAdr } = req.query;
  
  try {
      const user = await User.findOne({ userMetamaskAdr });
      if (user) {
          res.status(200).json(user);
      } else {
          res.status(404).json({ message: 'User not found' });
      }
  } catch (error) {
      res.status(500).json({ message: error.message });
  }
});

module.exports = router;

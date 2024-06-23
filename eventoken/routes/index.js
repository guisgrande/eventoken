var express = require('express');
var router = express.Router();

/* GET home page. */
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

module.exports = router;

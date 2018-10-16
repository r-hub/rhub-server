
module.exports = function(str) {
  if (typeof str === 'string' || str instanceof String) {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  } else  {
    return str;
  }
}

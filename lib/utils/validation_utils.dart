bool passwordConfirmed(String password, String confirmedPassword) {
  if (password.trim() == confirmedPassword.trim()) {
    return true;
  } else {
    return false;
  }
}

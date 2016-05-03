import $ from 'jquery';

export function validateCaptcha({ str, user }) {
  return $.ajax({
    url: '/send_verify_code',
    data: {
      _rucaptcha: str,
      user,
    },
  });
}

export function createUser({ verify_code, user }) {
  return $.ajax({
    url: '/signup',
    method: 'POST',
    data: {
      verify_code,
      user,
    },
  });
}

export function initWechatLogin() {
  return new WxLogin({
    id: 'wechatQR',
    appid: 'wxd469c54993b2a659',
    scope: 'snsapi_login',
    redirect_uri: 'http://geekpark.net/users/auth/wechat/callback',
    state: '',
    style: '',
    href: '',
  });
}

export function updateUser(data) {
  return $.ajax({
    url: '/my',
    method: 'PATCH',
    data,
  });
}

export function uploadAvatar(data) {
  return $.ajax({
    url: '/my',
    method: 'PATCH',
    catch: false,
    processData: false,
    contentType: false,
    data,
  });
}

// user: { email/mobile, password }, verify_code: xxxxxx
export function resetPassword({ verify_code, user }) {
  return $.ajax({
    url: '/reset_password',
    method: 'POST',
    data: {
      verify_code,
      user,
    },
  });
}

export function checkExist(id) {
  return $.ajax({
    url: 'check_exist',
    data: {
      user: { email: id },
    },
  });
}

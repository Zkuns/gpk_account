import React, { PropTypes } from 'react';

import Captcha from '../share/Captcha';

import { sendVerify } from '../../share/server';
import { parseErr } from '../../share/utils';

class ValidatorIMG extends React.Component {
  constructor(props) {
    super(props);

    this.submit = () => {
      const v = this.refs.captcha.getValue();
      if (!v) return;

      sendVerify({ str: v, id: props.user.id, isEmail: props.user.isEmail })
        .done(() => {
          this.props.onClose();
          this.props.sendVerifyCode();
          this.props.validateUser();
          this.props.showMessage({ type: 'success', msg: '验证码发送成功' });
        })
        .fail(xhr => {
          const errStr = parseErr(xhr.responseText);
          if (errStr) this.props.showMessage({ type: 'error', msg: errStr });
          this.refs.captcha.random();
        });
    };
  }

  componentDidMount() {
    this.refs.form.addEventListener('submit', e => {
      e.preventDefault();
      this.submit();
    });
  }

  render() {
    return (
      <div>
        <div className="modal-title">
          请输入下面的图形验证码
        </div>
        <i className="iconfont icon-close modal-close" onClick={this.props.onClose}></i>
        <form ref="form">
          <Captcha className="mb-input" ref="captcha" />
          <button className="btn btn-large">提交</button>
        </form>
      </div>
    );
  }
}

ValidatorIMG.propTypes = {
  user: PropTypes.object.isRequired,
  onClose: PropTypes.func.isRequired,
  sendVerifyCode: PropTypes.func.isRequired,
  validateUser: PropTypes.func.isRequired,
  showMessage: PropTypes.func.isRequired,
};

export default ValidatorIMG;

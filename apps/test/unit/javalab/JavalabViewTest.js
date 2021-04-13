import React from 'react';
import {expect} from '../../util/reconfiguredChai';
import {shallow} from 'enzyme';
// import JavalabView from '@cdo/apps/javalab/JavalabView';
import {UnconnectedJavalabView as JavalabView} from '@cdo/apps/javalab/JavalabView';
// import {Provider} from 'react-redux';
// import pageConstants, {setPageConstants} from '@cdo/apps/redux/pageConstants';
// import {
//   getStore,
//   registerReducers,
//   stubRedux,
//   restoreRedux
// } from '@cdo/apps/redux';
// import javalab, {toggleDarkMode} from '@cdo/apps/javalab/javalabRedux';
import color from '@cdo/apps/util/color';
global.$ = require('jquery');

describe('Java Lab View Test', () => {
  let defaultProps;

  beforeEach(() => {
    // stubRedux();
    // registerReducers({javalab});
    // registerReducers({pageConstants});
    // store = getStore();
    // store.dispatch(
    //   setPageConstants({
    //     isProjectLevel: true,
    //     isReadOnlyWorkspace: false,
    //     channelId: 'id',
    //     isEmbedView: false,
    //     isShareView: false
    //   })
    // );
    defaultProps = {
      onMount: () => {},
      onContinue: () => {},
      onCommitCode: () => {},
      isProjectLevel: false,
      isReadOnlyWorkspace: false,
      isDarkMode: false
    };
  });

  afterEach(() => {
    // restoreRedux();
  });

  // const createWrapper = () => {
  //   return shallow(
  //     // <Provider store={store}>
  //       <JavalabView {...defaultProps} />
  //     // </Provider>
  //   );
  // };

  describe('getButtonStyles', () => {
    it('Is cyan or orange in light mode', () => {
      let editor = shallow(<JavalabView {...defaultProps} />);
      const notSettings = editor
        // .find('JavalabView')
        .instance()
        .getButtonStyles(false);
      expect(notSettings.backgroundColor).to.equal(color.cyan);
      const settings = editor
        // .find('JavalabView')
        .instance()
        .getButtonStyles(true);
      expect(settings.backgroundColor).to.equal(color.orange);
    });

    it('Is grey in dark mode', () => {
      let props = {...defaultProps, isDarkMode: true};
      let editor = shallow(<JavalabView {...props} />);
      const notSettings = editor
        // .find('JavalabView')
        .instance()
        .getButtonStyles(false);
      expect(notSettings.backgroundColor).to.equal('#272822');
      const settings = editor
        // .find('JavalabView')
        .instance()
        .getButtonStyles(false);
      expect(settings.backgroundColor).to.equal('#272822');
    });
  });
});

import {TestResults} from '@cdo/apps/constants';
var blockUtils = require('@cdo/apps/block_utils');

module.exports = {
  app: 'maze',
  skinId: 'letters',
  levelFile: 'wordsearchLevels',
  levelId: 'k_6',
  tests: [
    {
      description: 'Verify solution',
      expected: {
        result: true,
        testResult: TestResults.ALL_PASS
      },
      customValidator: function() {
        return Maze.wordSearch !== undefined;
      },
      xml:
        '<xml>' +
        blockUtils.blocksFromList([
          'maze_moveEast',
          'maze_moveEast',
          'maze_moveEast',
          'maze_moveSouth'
        ]) +
        '</xml>'
    }
  ]
};

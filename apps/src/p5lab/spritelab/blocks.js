/* global dashboard */
/* global appOptions */

import {SVG_NS} from '@cdo/apps/constants';
import {getStore} from '@cdo/apps/redux';
import {getLocation} from './locationPickerModule';
import {APP_HEIGHT, P5LabInterfaceMode} from '../constants';
import {TOOLBOX_EDIT_MODE} from '../../constants';
import {animationSourceUrl} from '../animationListModule';
import {changeInterfaceMode} from '../actions';
import {
  Goal,
  show,
  showBackground
} from '../AnimationPicker/animationPickerModule';
import i18n from '@cdo/locale';
import spritelabMsg from '@cdo/spritelab/locale';
function animations(areBackgrounds) {
  const animationList = getStore().getState().animationList;
  if (!animationList || animationList.orderedKeys.length === 0) {
    console.warn('No sprites available');
    return [['sprites missing', 'null']];
  }
  let results = animationList.orderedKeys
    .filter(key => {
      const animation = animationList.propsByKey[key];
      const isBackground = (animation.categories || []).includes('backgrounds');
      return areBackgrounds ? isBackground : !isBackground;
    })
    .map(key => {
      const animation = animationList.propsByKey[key];
      if (animation.sourceUrl) {
        return [animation.sourceUrl, `"${animation.name}"`];
      } else {
        const url = animationSourceUrl(
          key,
          animation,
          getStore().getState().pageConstants.channelId
        );
        return [url, `"${animation.name}"`];
      }
    });
  // In case either all backgrounds or all costumes are missing and we request them, this allows the "create
  // new sprite" and "set background as" blocks to continue working without crashing.
  // When they are used without sprites being set, the image dropdown for those blocks will be empty except
  // for the "More" button. The user will have to add sprites/backgrounds to this dropdown one by one using the "More" button.
  if (results.length === 0) {
    return [['sprites missing', 'null']];
  }
  return results;
}
function sprites() {
  return animations(false);
}
function backgroundList() {
  return animations(true);
}

// This color palette is limited to colors which have different hues, therefore
// it should not contain different shades of the same color such as
// ['#ff0000', '#cc0000', '#880000'].
const limitedColours = [
  // fully-saturated primary colors
  '#ff0000', // RED
  '#00ff00', // GREEN
  '#0000ff', // BLUE

  // fully-saturated secondary colors
  '#ffff00', // YELLOW
  '#00ffff', // CYAN
  '#ff00ff', // MAGENTA

  // some "tertiary" colors
  '#ff8800', // ORANGE
  '#8800ff', // PURPLE
  '#00ff88' // LIME
];

const customInputTypes = {
  locationPicker: {
    addInput(blockly, block, inputConfig, currentInputRow) {
      currentInputRow.appendTitle(
        `${inputConfig.label}(0, 0)`,
        `${inputConfig.name}_LABEL`
      );
      const label =
        currentInputRow.titleRow[currentInputRow.titleRow.length - 1];
      const icon = document.createElementNS(SVG_NS, 'tspan');
      icon.style.fontFamily = 'FontAwesome';
      icon.textContent = '\uf276';
      const button = new Blockly.FieldButton(
        icon,
        updateValue => {
          getLocation(loc => {
            if (loc) {
              button.setValue(JSON.stringify(loc));
            }
          });
        },
        block.getHexColour(),
        value => {
          if (value) {
            try {
              const loc = JSON.parse(value);
              label.setText(
                `${inputConfig.label}(${loc.x}, ${APP_HEIGHT - loc.y})`
              );
            } catch (e) {
              // Just ignore bad values
            }
          }
        }
      );
      currentInputRow.appendTitle(button, inputConfig.name);
    },
    generateCode(block, arg) {
      return `(${block.getTitleValue(arg.name)})`;
    }
  },
  locationVariableDropdown: {
    addInput(blockly, block, inputConfig, currentInputRow) {
      block.getVars = function() {
        return {
          [Blockly.BlockValueType.LOCATION]: [
            block.getTitleValue(inputConfig.name)
          ]
        };
      };
      block.renameVar = function(oldName, newName) {
        if (
          Blockly.Names.equals(oldName, block.getTitleValue(inputConfig.name))
        ) {
          block.setTitleValue(newName, inputConfig.name);
        }
      };
      block.removeVar = function(oldName) {
        if (
          Blockly.Names.equals(oldName, block.getTitleValue(inputConfig.name))
        ) {
          block.dispose(true, true);
        }
      };

      currentInputRow
        .appendTitle(inputConfig.label)
        .appendTitle(Blockly.Msg.VARIABLES_GET_TITLE)
        .appendTitle(
          new Blockly.FieldVariable(
            Blockly.Msg.VARIABLES_SET_ITEM,
            null,
            null,
            Blockly.BlockValueType.LOCATION,
            null
          ),
          inputConfig.name
        )
        .appendTitle(Blockly.Msg.VARIABLES_GET_TAIL);
    },
    generateCode(block, arg) {
      return Blockly.JavaScript.translateVarName(block.getTitleValue(arg.name));
    }
  },
  soundPicker: {
    addInput(blockly, block, inputConfig, currentInputRow) {
      var onSelect = function(soundValue) {
        block.setTitleValue(soundValue, inputConfig.name);
      };
      currentInputRow.appendTitle(inputConfig.label).appendTitle(
        new Blockly.FieldDropdown([['Choose', 'Choose']], () => {
          dashboard.assets.showAssetManager(onSelect, 'audio', null, {
            libraryOnly: true
          });
        }),
        inputConfig.name
      );
    },
    generateCode(block, arg) {
      return `'${block.getTitleValue(arg.name)}'`;
    }
  },
  costumePicker: {
    addInput(blockly, block, inputConfig, currentInputRow) {
      let buttons;
      if (
        getStore().getState().pageConstants &&
        getStore().getState().pageConstants.showAnimationMode
      ) {
        buttons = [
          {
            text: i18n.draw(),
            action: () => {
              getStore().dispatch(
                changeInterfaceMode(
                  P5LabInterfaceMode.ANIMATION,
                  true /* spritelabDraw */
                )
              );
            }
          },
          {
            text: i18n.more(),
            action: () => {
              getStore().dispatch(show(Goal.NEW_ANIMATION, true));
            }
          }
        ];
      }
      currentInputRow
        .appendTitle(inputConfig.label)
        .appendTitle(
          new Blockly.FieldImageDropdown(sprites, 32, 32, buttons),
          inputConfig.name
        );
    },
    generateCode(block, arg) {
      return block.getTitleValue(arg.name);
    }
  },
  backgroundPicker: {
    addInput(blockly, block, inputConfig, currentInputRow) {
      let buttons;
      if (
        getStore().getState().pageConstants &&
        getStore().getState().pageConstants.showAnimationMode
      ) {
        buttons = [
          {
            text: i18n.more(),
            action: () => {
              getStore().dispatch(showBackground(Goal.NEW_ANIMATION));
            }
          }
        ];
      }
      currentInputRow
        .appendTitle(inputConfig.label)
        .appendTitle(
          new Blockly.FieldImageDropdown(backgroundList, 40, 40, buttons),
          inputConfig.name
        );
    },
    generateCode(block, arg) {
      return block.getTitleValue(arg.name);
    }
  },
  spritePointer: {
    addInput(blockly, block, inputConfig, currentInputRow) {
      if (Object.keys(spritelabMsg).length === 0) {
        // spritelab i18n is not available on Levelbuilder
        block.shortString = ' ';
        block.longString = ' ';
      } else {
        switch (block.type) {
          case 'gamelab_clickedSpritePointer':
            block.shortString = spritelabMsg.clicked();
            block.longString = spritelabMsg.clickedSprite();
            break;
          case 'gamelab_newSpritePointer':
            block.shortString = spritelabMsg.new();
            block.longString = spritelabMsg.newSprite();
            break;
          case 'gamelab_subjectSpritePointer':
            block.shortString = spritelabMsg.subject();
            block.longString = spritelabMsg.subjectSprite();
            break;
          case 'gamelab_objectSpritePointer':
            block.shortString = spritelabMsg.object();
            block.longString = spritelabMsg.objectSprite();
            break;
          default:
            // unsupported block for spritePointer, leave the block text blank
            block.shortString = '';
            block.longString = '';
        }
      }
      block.thumbnailSize = 32;
      currentInputRow
        .appendTitle(block.longString)
        .appendTitle(
          new Blockly.FieldImage('', 1, block.thumbnailSize),
          inputConfig.name
        );
    },
    generateCode(block, arg) {
      switch (block.type) {
        case 'gamelab_clickedSpritePointer':
          return '{id: extraArgs.clickedSprite}';
        case 'gamelab_newSpritePointer':
          return '{id: extraArgs.newSprite}';
        case 'gamelab_subjectSpritePointer':
          return '{id: extraArgs.subjectSprite}';
        case 'gamelab_objectSpritePointer':
          return '{id: extraArgs.objectSprite}';
        default:
          // unsupported block for spritePointer, returning undefined here
          // will match the behavior of an empty socket.
          return undefined;
      }
    }
  },
  spritePicker: {
    addInput(blockly, block, inputConfig, currentInputRow) {
      block.getVars = function() {
        return {
          [Blockly.BlockValueType.SPRITE]: [
            block.getTitleValue(inputConfig.name)
          ]
        };
      };
      block.renameVar = function(oldName, newName) {
        if (
          Blockly.Names.equals(oldName, block.getTitleValue(inputConfig.name))
        ) {
          block.setTitleValue(newName, inputConfig.name);
        }
      };
      block.removeVar = function(oldName) {
        if (
          Blockly.Names.equals(oldName, block.getTitleValue(inputConfig.name))
        ) {
          block.dispose(true, true);
        }
      };
      block.superSetTitleValue = block.setTitleValue;
      block.setTitleValue = function(newValue, name) {
        if (name === inputConfig.name && block.blockSpace.isFlyout) {
          newValue = Blockly.Variables.generateUniqueName(newValue);
        }
        block.superSetTitleValue(newValue, name);
      };

      currentInputRow
        .appendTitle(inputConfig.label)
        .appendTitle(
          new Blockly.FieldVariable(
            null,
            null,
            null,
            Blockly.BlockValueType.SPRITE,
            i18n.sprite()
          ),
          inputConfig.name
        );
    },
    generateCode(block, arg) {
      return `{name: '${block.getTitleValue(arg.name)}'}`;
    }
  },
  limitedColourPicker: {
    addInput(blockly, block, inputConfig, currentInputRow) {
      const options = {
        colours: limitedColours,
        columns: 3
      };
      currentInputRow
        .appendTitle(inputConfig.label)
        .appendTitle(
          new Blockly.FieldColour('#ff0000', undefined, options),
          'VAL'
        );
    },
    generateCode(block, arg) {
      return `'${block.getTitleValue(arg.name)}'`;
    }
  },
  // Custom input for a variable input that generates the name of the variable
  // rather than the value of the variable.
  variableNamePicker: {
    addInputRow(blockly, block, inputConfig) {
      return block.appendValueInput(inputConfig.name);
    },

    generateCode(block, arg) {
      const input = block.getInput(arg.name);
      if (input) {
        const targetBlock = input.connection.targetBlock();
        if (targetBlock && targetBlock.type === 'variables_get') {
          return `'${Blockly.JavaScript.blockToCode(targetBlock)[0]}'`;
        }
      }
      return '';
    }
  }
};

export default {
  sprites,
  customInputTypes,
  install(blockly, blockInstallOptions) {}
};

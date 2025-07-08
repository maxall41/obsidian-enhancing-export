import type { ExportSetting } from './settings';

/*
 * Variables
 * - ${attachmentFolderPath}  --> obsidian' settings.
 *
 *   /User/aaa/Documents/test.pdf
 * - ${outputDir}             --> /User/aaa/Documents/
 * - ${outputPath}            --> /User/aaa/Documents/test.pdf
 * - ${outputFileName}        --> test
 * - ${outputFileFullName}    --> test.pdf
 *
 *   /User/aaa/Documents/test.pdf
 * - ${currentDir}            --> /User/aaa/Documents/
 * - ${currentPath}           --> /User/aaa/Documents/test.pdf
 * - ${currentFileName}       --> test
 * - ${CurrentFileFullName}   --> test.pdf
 */

export default {
  'Academic Note': {
    name: 'Academic Note',
    type: 'pandoc',
    arguments:
      '-f ${fromFormat} --resource-path="${currentDir}" --resource-path="${attachmentFolderPath}" --pdf-engine=typst --template=/Users/maxcampbell/Documents/Main/template.typ --lua-filter="${luaDir}/rm.lua"  -s -o "${outputPath}" ',
    extension: '.pdf',
  },
} satisfies Record<string, ExportSetting> as Record<string, ExportSetting>;

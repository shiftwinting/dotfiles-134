#!/usr/bin/env node

const fs = require('fs');
const argparse = require('argparse');
const markdownIt = require('markdown-it');
const markdownItTaskCheckbox = require('markdown-it-task-checkbox');
const markdownItEmoji = require('markdown-it-emoji');
const markdownItHeaderAnchors = require('./markdown-it-header-anchors');
const Prism = require('prismjs/components/prism-core');
const loadPrismLanguages = require('prismjs/components/');
const PRISM_COMPONENTS = require('prismjs/components.js');

// TODO: integrate <https://github.com/PrismJS/prism-themes>
const PRISM_THEMES = Object.keys(PRISM_COMPONENTS.themes).filter((k) => k !== 'meta');

let parser = new argparse.ArgumentParser();

parser.add_argument('INPUT_FILE', {
  nargs: argparse.OPTIONAL,
  help: '(stdin by default)',
});
parser.add_argument('OUTPUT_FILE', {
  nargs: argparse.OPTIONAL,
  help: '(stdout by default)',
});

parser.add_argument('--input-encoding', {
  default: 'utf-8',
  help: '(utf-8 by default)',
});
parser.add_argument('--output-encoding', {
  default: 'utf-8',
  help: '(utf-8 by default)',
});

parser.add_argument('--no-default-stylesheets', {
  action: argparse.BooleanOptionalAction,
});
parser.add_argument('--syntax-theme', {
  choices: [...PRISM_THEMES, 'none', 'dotfiles'],
});

parser.add_argument('--stylesheet', {
  nargs: argparse.ZERO_OR_MORE,
});
parser.add_argument('--script', {
  nargs: argparse.ZERO_OR_MORE,
});

let args = parser.parse_args();

loadPrismLanguages(); // loads all languages

let md = markdownIt({
  html: true,
  linkify: true,
  highlight: (code, lang) => {
    if (lang && Object.prototype.hasOwnProperty.call(Prism.languages, lang)) {
      return Prism.highlight(code, Prism.languages[lang], lang);
    }
    return null;
  },
});
md.use(markdownItTaskCheckbox);
md.use(markdownItEmoji);
md.use(markdownItHeaderAnchors);

let markdownDocument = fs.readFileSync(args.INPUT_FILE || 0, args.input_encoding);
let renderedMarkdown = md.render(markdownDocument);

let stylesheetsTexts = [];
let scriptsTexts = [];
let syntaxThemeName = null;

console.log(Object.entries(args));
if (!args.no_default_stylesheets) {
  syntaxThemeName = 'dotfiles';
  stylesheetsTexts.push(
    fs.readFileSync(require.resolve('github-markdown-css/github-markdown.css'), 'utf-8'),
    fs.readFileSync(require.resolve('./github-markdown-additions.css'), 'utf-8'),
  );
}

syntaxThemeName = args.syntax_theme || syntaxThemeName;
if (syntaxThemeName && syntaxThemeName !== 'none') {
  stylesheetsTexts.push(
    fs.readFileSync(
      require.resolve(
        syntaxThemeName === 'dotfiles'
          ? '../../colorschemes/out/prismjs-theme.css'
          : `prismjs/themes/${syntaxThemeName}.css`,
      ),
      'utf-8',
    ),
  );
}

for (let stylesheetPath of args.stylesheet || []) {
  stylesheetsTexts.push(fs.readFileSync(stylesheetPath));
}

for (let scriptPath of args.script || []) {
  scriptsTexts.push(fs.readFileSync(scriptPath));
}

let renderedHtmlDocument = `
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="X-UA-Compatible" content="ie=edge">
${stylesheetsTexts.map((s) => `<style>\n${s}\n</style>`).join('\n')}
</head>
<body>
<article class="markdown-body">
${renderedMarkdown}
</article>
${scriptsTexts.map((s) => `<script>\n${s}\n</script>`).join('\n')}
</body>
</html>
`.trim();

fs.writeFileSync(args.OUTPUT_FILE || 1, renderedHtmlDocument, args.output_encoding);

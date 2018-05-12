import coffee2 from 'rollup-plugin-coffee2';
import nodeResolve from 'rollup-plugin-node-resolve';

export default {
  input: 'src/index.coffee',
  output: [{
    file: 'lib/component-register.js',
    format: 'cjs',
    exports: 'named'
  }, {
    file: 'dist/component-register.js',
    format: 'es'
  }],
  plugins: [
    coffee2(),
    nodeResolve({ extensions: ['.js', '.coffee'] })
  ]
};
import nodeResolve from 'rollup-plugin-node-resolve';

export default {
  input: 'src/index.js',
  output: [{
    file: 'lib/component-register.js',
    format: 'cjs',
    exports: 'named'
  }, {
    file: 'dist/component-register.js',
    format: 'es'
  }],
  plugins: [
    nodeResolve({ extensions: ['.js'] })
  ]
};
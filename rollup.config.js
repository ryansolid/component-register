import nodeResolve from 'rollup-plugin-node-resolve';
import babel from 'rollup-plugin-babel';

export default {
  input: 'src/index.ts',
  output: [{
    file: 'lib/component-register.js',
    format: 'cjs',
    exports: 'named'
  }, {
    file: 'dist/component-register.js',
    format: 'es'
  }],
  plugins: [
    nodeResolve({ extensions: ['.js', '.ts'] }),
    babel({
      extensions: ['.js', '.ts'],
      presets: ["@babel/preset-typescript"],
      exclude: 'node_modules/**'
    })
  ]
};
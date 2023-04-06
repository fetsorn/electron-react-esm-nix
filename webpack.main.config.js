const path = require('path');

module.exports = {
  entry: './src/main/index.js',
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
        },
      },
    ],
  },
  resolve: {
    alias: {
      api: path.resolve(__dirname, './src/api'),
    },
    extensions: ['.js', '.jsx', '.css', '.json'],
  },
};

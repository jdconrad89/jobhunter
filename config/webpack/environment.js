const { environment } = require('@rails/webpacker')

// Add babel-loader configuration for JSX files
environment.loaders.append('jsx', {
  test: /\.(js|jsx)$/,
  exclude: /node_modules/,
  use: {
    loader: 'babel-loader',
    options: {
      presets: ['@babel/preset-env', '@babel/preset-react']
    }
  }
})

module.exports = environment

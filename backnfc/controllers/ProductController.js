const Product = require('../models/Product');

exports.find = async function (_id) {
  const result = await Product.findOne({ id: _id });
  if (!result) return { result: 'No existe', code: 404, message: 'No existe este producto.' };
  return { result, code: 200, message: 'Articulo obtenido correctamente.' };
};

exports.create = async function (data) {
  const product = new Product({
    id: data.nfcId,
    name: data.name,
    value: data.value,
    amount: data.amount
  })
  return product.save().then(async () => {
    return { result: 'Producto creado correctamente', code: 200, message: 'Producto creado correctamente' }
  }).catch(() => {
    return { result, code: 422, message: 'Error creando el producto en la base de datos.' }
  })
}

exports.update = async function (data) {
  return Product.findOne({ id: data.id }).then(async (product) => {
    if (!product) return { result: 'No encontrado', code: 404 }
    product.name = data.name ? data.name : product.name
    product.value = data.value ? data.value : product.value
    product.amount = data.amount ? data.amount : product.amount
    return product.save().then(async (result) => {
      return { result, code: 200, message: 'Se ha actualizado correctamente.' }
    }).catch(() => {
      return { result: 'Hubo un error al guardar la informacion.', code: 422, message: 'Hubo un error al guardar la informacion.' }
    })
  }).catch(() => {
    return { result: 'Hubo un error obteniendo el producto.', code: 400, message: 'Hubo un error obteniendo el producto.' }
  })
}

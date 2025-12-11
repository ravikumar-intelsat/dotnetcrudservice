using MyCrudApi.Models;

namespace MyCrudApi.Services
{
    public class ProductService
    {
        private readonly List<Product> _products = new();

        public ProductService()
        {
            _products.AddRange(new[]
            {
                new Product { Id = 1, Name = "Laptop", Price = 999.99m },
                new Product { Id = 2, Name = "Smartphone", Price = 499.99m },
                new Product { Id = 3, Name = "Headphones", Price = 79.99m }
            });
        }

        public IEnumerable<Product> GetAll() => _products;

        public Product? GetById(int id) => _products.FirstOrDefault(p => p.Id == id);

        public Product Create(Product product)
        {
            product.Id = _products.Count + 1;
            _products.Add(product);
            return product;
        }

        public bool Update(int id, Product updated)
        {
            var p = _products.FirstOrDefault(x => x.Id == id);
            if (p == null) return false;

            p.Name = updated.Name;
            p.Price = updated.Price;
            return true;
        }

        public bool Delete(int id)
        {
            var p = _products.FirstOrDefault(x => x.Id == id);
            return p != null && _products.Remove(p);
        }
    }
}

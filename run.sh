#!/bin/bash

PROJECT_NAME=${1:-MyCrudApi}

echo "🚀 Creating ASP.NET Core Web API project: $PROJECT_NAME"

# Create project folder
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Create new ASP.NET Core Web API
dotnet new webapi -n $PROJECT_NAME

cd $PROJECT_NAME

# -----------------------------
# Create Models/Product.cs
# -----------------------------
mkdir -p Models

cat <<EOF > Models/Product.cs
namespace $PROJECT_NAME.Models
{
    public class Product
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public decimal Price { get; set; }
    }
}
EOF

# -----------------------------
# Create Services/ProductService.cs
# -----------------------------
mkdir -p Services

cat <<EOF > Services/ProductService.cs
using $PROJECT_NAME.Models;

namespace $PROJECT_NAME.Services
{
    public class ProductService
    {
        private readonly List<Product> _products = new();

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
EOF

# -----------------------------
# Create Controllers/ProductController.cs
# -----------------------------
mkdir -p Controllers

cat <<EOF > Controllers/ProductController.cs
using Microsoft.AspNetCore.Mvc;
using $PROJECT_NAME.Models;
using $PROJECT_NAME.Services;

namespace $PROJECT_NAME.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductController : ControllerBase
    {
        private readonly ProductService _service;

        public ProductController(ProductService service)
        {
            _service = service;
        }

        [HttpGet]
        public IActionResult GetAll() => Ok(_service.GetAll());

        [HttpGet("{id}")]
        public IActionResult GetById(int id)
        {
            var item = _service.GetById(id);
            return item == null ? NotFound() : Ok(item);
        }

        [HttpPost]
        public IActionResult Create(Product product)
        {
            var created = _service.Create(product);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }

        [HttpPut("{id}")]
        public IActionResult Update(int id, Product product)
        {
            return _service.Update(id, product) ? NoContent() : NotFound();
        }

        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            return _service.Delete(id) ? NoContent() : NotFound();
        }
    }
}
EOF

# -----------------------------
# Register service in Program.cs
# -----------------------------

sed -i 's|var app = builder.Build();|builder.Services.AddSingleton<'$PROJECT_NAME'.Services.ProductService>();\n\nvar app = builder.Build();|' Program.cs

echo "✅ Project setup complete!"
echo "▶ Running project..."
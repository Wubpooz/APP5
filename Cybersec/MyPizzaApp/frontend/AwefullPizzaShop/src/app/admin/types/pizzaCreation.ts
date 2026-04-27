export interface PizzaCreation {
  name: string;            // Name of the product
  price: number;           // Price in the appropriate currency
  imageUrl: string;        // URL of the product image
  description: string;     // Product description
  category: 'MEAT' | 'FISH' | 'VEGAN';
}

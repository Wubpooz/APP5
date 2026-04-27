import {UserComment} from './userComment';

export interface Pizza {
  id: string;              // Unique identifier for the product
  name: string;            // Name of the product
  price: number;           // Price in the appropriate currency
  imageUrl: string;        // URL of the product image
  description: string;     // Product description
}

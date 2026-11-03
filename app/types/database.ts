export type AppRole = 'super_admin' | 'admin' | 'viewer'
export type SizeType = 'footwear' | 'clothing' | 'universal'

// Supabase tipovi rade samo s `type`, a ne s `interface`.
export type Category = {
  id: string
  parent_id: string | null
  name: string
  slug: string
  description: string | null
  sort_order: number
  is_active: boolean
  created_at: string
  updated_at: string
}

export type Product = {
  id: string
  sku: string
  name: string
  category_id: string
  description: string | null
  material: string | null
  care: string | null
  size_guide: string | null
  size_type: SizeType
  price: number
  // Upisuje se postotak, a baza sama računa sniženu cijenu.
  discount_percent: number | null
  sale_price: number | null
  dress_length: string | null
  heel_height: string | null
  weight_grams: number | null
  is_visible: boolean
  store_only: boolean
  meta_title: string | null
  meta_description: string | null
  // Arhiviran proizvod nije na webu ni na popisu, ali ostaje u bazi za statistiku.
  archived_at: string | null
  created_at: string
  updated_at: string
}

export type ProductColor = {
  id: string
  product_id: string
  name: string
  hex: string
  slug: string
  sort_order: number
}

export type ProductSize = {
  id: string
  color_id: string
  size: string
  quantity: number
  sort_order: number
}

export type ProductImage = {
  id: string
  color_id: string
  path: string
  alt: string
  sort_order: number
}

export type ProductAuditEntry = {
  id: string
  product_id: string
  sku: string
  name: string
  action: 'created' | 'updated' | 'deleted' | 'stock' | 'archived' | 'restored'
  user_id: string | null
  user_email: string | null
  created_at: string
  // Postoji samo uz izmjenu količine.
  details: { color: string; size: string; from: number; to: number }[] | null
}

export type ProductPayload = Pick<Product,
  'id' | 'sku' | 'name' | 'category_id' | 'description' | 'material' | 'care' | 'size_guide'
  | 'size_type' | 'price' | 'discount_percent' | 'dress_length' | 'heel_height' | 'weight_grams' | 'is_visible' | 'store_only' | 'meta_title' | 'meta_description'
> & {
  extra_category_ids: string[]
  brand: string | null
  colors: (Pick<ProductColor, 'id' | 'name' | 'hex' | 'slug' | 'sort_order'> & {
    sizes: Pick<ProductSize, 'size' | 'quantity' | 'sort_order'>[]
    images: Pick<ProductImage, 'id' | 'path' | 'alt' | 'sort_order'>[]
  })[]
}

// Stavka košarice kako je vraća shop_cart. `stock` je trenutna količina na stanju.
export type ShopCartItemRow = {
  sizeId: string
  size: string
  quantity: number
  stock: number
  colorId: string
  colorName: string
  hex: string
  slug: string
  productName: string
  sku: string
  price: number
  compareAtPrice: number | null
  imagePath: string | null
  imageAlt: string | null
}

export type ShopWishlistRow = {
  id: string
  slug: string
  productName: string
  colorName: string
  categoryName: string | null
  price: number
  compareAtPrice: number | null
  imagePath: string | null
  imageAlt: string | null
  soldOut: boolean
  storeOnly: boolean
  colors: { id: string; name: string; hex: string }[]
}

export type InquiryCustomerInput = {
  name: string
  phone: string
  address: string
  postal_code: string
  city: string
  email: string
  note: string
}

export type InquiryStatus = 'new' | 'in_progress' | 'sold' | 'cancelled'

// Povijest narudžbe. Narudžbu stvara kupac, pa `created` nema korisnika.
export type InquiryAuditEntry = {
  id: string
  inquiry_id: string
  inquiry_number: number
  action: 'created' | 'status' | 'deleted'
  from_status: InquiryStatus | null
  to_status: InquiryStatus | null
  user_id: string | null
  user_email: string | null
  created_at: string
}

export type Inquiry = {
  id: string
  number: number
  status: InquiryStatus
  customer_name: string
  phone: string
  email: string | null
  note: string | null
  address: string | null
  postal_code: string | null
  city: string | null
  // Sveukupno (total) = ukupno za proizvode (subtotal) + poštarina.
  subtotal: number
  shipping: number
  total: number
  // Zadnja promjena statusa, upisuje je baza.
  status_changed_at: string | null
  status_changed_by: string | null
  status_changed_by_email: string | null
  session_id: string | null
  created_at: string
  updated_at: string
}

export type InquiryItem = {
  id: string
  inquiry_id: string
  product_id: string | null
  color_id: string | null
  size_id: string | null
  sku: string
  product_name: string
  color_name: string
  size: string
  unit_price: number
  regular_price: number
  quantity: number
}

export type TeamMember = {
  user_id: string
  email: string
  role: AppRole
  created_at: string
  last_sign_in_at: string | null
  is_blocked: boolean
}

type Relationship = {
  foreignKeyName: string
  columns: string[]
  isOneToOne: false
  referencedRelation: string
  referencedColumns: string[]
}

export type Database = {
  public: {
    Tables: {
      user_roles: {
        Row: { user_id: string; role: AppRole; created_at: string }
        Insert: { user_id: string; role: AppRole; created_at?: string }
        Update: { user_id?: string; role?: AppRole; created_at?: string }
        Relationships: []
      }
      categories: {
        Row: Category
        Insert: Pick<Category, 'name' | 'slug'> & Partial<Category>
        Update: Partial<Category>
        Relationships: []
      }
      product_audit_log: {
        Row: ProductAuditEntry
        Insert: Partial<ProductAuditEntry>
        Update: Partial<ProductAuditEntry>
        Relationships: []
      }
      products: {
        Row: Product
        Insert: Partial<Product>
        Update: Partial<Product>
        Relationships: [Relationship & {
          foreignKeyName: 'products_category_id_fkey'
          columns: ['category_id']
          referencedRelation: 'categories'
          referencedColumns: ['id']
        }]
      }
      product_categories: {
        Row: { product_id: string; category_id: string }
        Insert: { product_id: string; category_id: string }
        Update: { product_id?: string; category_id?: string }
        Relationships: [
          Relationship & {
            foreignKeyName: 'product_categories_product_id_fkey'
            columns: ['product_id']
            referencedRelation: 'products'
            referencedColumns: ['id']
          },
          Relationship & {
            foreignKeyName: 'product_categories_category_id_fkey'
            columns: ['category_id']
            referencedRelation: 'categories'
            referencedColumns: ['id']
          },
        ]
      }
      // Upisuje ih samo shop_submit_inquiry. Iz aplikacije se mijenja samo status.
      inquiries: {
        Row: Inquiry
        Insert: never
        Update: { status?: InquiryStatus }
        Relationships: []
      }
      inquiry_audit_log: {
        Row: InquiryAuditEntry
        Insert: never
        Update: never
        Relationships: []
      }
      inquiry_items: {
        Row: InquiryItem
        Insert: never
        Update: never
        Relationships: [Relationship & {
          foreignKeyName: 'inquiry_items_inquiry_id_fkey'
          columns: ['inquiry_id']
          referencedRelation: 'inquiries'
          referencedColumns: ['id']
        }]
      }
      // Vidi je samo tim, a ne kupci.
      product_internal: {
        Row: { product_id: string; brand: string | null }
        Insert: { product_id: string; brand?: string | null }
        Update: { product_id?: string; brand?: string | null }
        Relationships: [Omit<Relationship, 'isOneToOne'> & {
          foreignKeyName: 'product_internal_product_id_fkey'
          columns: ['product_id']
          isOneToOne: true
          referencedRelation: 'products'
          referencedColumns: ['id']
        }]
      }
      product_colors: {
        Row: ProductColor
        Insert: Partial<ProductColor>
        Update: Partial<ProductColor>
        Relationships: [Relationship & {
          foreignKeyName: 'product_colors_product_id_fkey'
          columns: ['product_id']
          referencedRelation: 'products'
          referencedColumns: ['id']
        }]
      }
      product_sizes: {
        Row: ProductSize
        Insert: Partial<ProductSize>
        Update: Partial<ProductSize>
        Relationships: [Relationship & {
          foreignKeyName: 'product_sizes_color_id_fkey'
          columns: ['color_id']
          referencedRelation: 'product_colors'
          referencedColumns: ['id']
        }]
      }
      product_images: {
        Row: ProductImage
        Insert: Partial<ProductImage>
        Update: Partial<ProductImage>
        Relationships: [Relationship & {
          foreignKeyName: 'product_images_color_id_fkey'
          columns: ['color_id']
          referencedRelation: 'product_colors'
          referencedColumns: ['id']
        }]
      }
    }
    Views: { [_ in never]: never }
    Functions: {
      adjust_product_stock: { Args: { p_product_id: string; p_changes: { size_id: string; delta: number }[] }; Returns: undefined }
      archive_product: { Args: { p_product_id: string }; Returns: string[] }
      archive_products: { Args: { p_ids: string[] }; Returns: string[] }
      shop_cart: { Args: { p_session: string }; Returns: ShopCartItemRow[] }
      shop_cart_update: {
        Args: { p_session: string; p_size_id: string; p_quantity: number; p_add?: boolean }
        Returns: ShopCartItemRow[]
      }
      shop_wishlist: { Args: { p_session: string }; Returns: ShopWishlistRow[] }
      shop_wishlist_set: { Args: { p_session: string; p_color_id: string; p_on: boolean }; Returns: ShopWishlistRow[] }
      shop_submit_inquiry: {
        Args: { p_session: string; p_customer: InquiryCustomerInput }
        Returns: { number: number }
      }
      admin_products: {
        Args: { p_filters: Record<string, unknown>; p_sort: string; p_limit: number; p_offset: number }
        Returns: { total: number; ids: string[] }
      }
      admin_product_filter_options: {
        Args: { p_filters: Record<string, unknown> }
        Returns: {
          brands: string[]
          colors: { name: string; hex: string }[]
          sizes: string[]
          sizeTypes: SizeType[]
          minPrice: number | null
          maxPrice: number | null
        }
      }
      bulk_update_products: {
        Args: { p_ids: string[]; p_changes: { is_visible: boolean } | { store_only: boolean } | { discount_percent: number | null } }
        Returns: { updated: number; skipped: number }
      }
      current_user_role: { Args: Record<string, never>; Returns: AppRole | null }
      product_brands: { Args: Record<string, never>; Returns: string[] }
      shop_cards: {
        Args: {
          p_category_ids: string[] | null
          p_colors: string[] | null
          p_sizes: string[] | null
          p_lengths: string[] | null
          p_heels: string[] | null
          p_min_price: number | null
          p_max_price: number | null
          p_in_stock: boolean
          p_on_sale: boolean
          p_sort: string
          p_limit: number
          p_offset: number
        }
        Returns: {
          total: number
          cards: {
            id: string
            slug: string
            productName: string
            colorName: string
            categoryName: string | null
            price: number
            compareAtPrice: number | null
            imagePath: string | null
            imageAlt: string | null
            soldOut: boolean
            storeOnly: boolean
            colors: { id: string; name: string; hex: string }[]
          }[]
        }
      }
      shop_filter_options: {
        Args: { p_category_ids: string[] | null }
        Returns: {
          colors: { name: string; hex: string }[]
          sizes: string[]
          lengths: string[]
          heels: string[]
          hasSale: boolean
          minPrice: number | null
          maxPrice: number | null
        }
      }
      list_team_members: { Args: Record<string, never>; Returns: TeamMember[] }
      save_product_with_categories: { Args: { payload: ProductPayload }; Returns: string }
    }
    Enums: { app_role: AppRole }
    CompositeTypes: { [_ in never]: never }
  }
}

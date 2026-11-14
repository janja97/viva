export type AppRole = 'super_admin' | 'admin' | 'viewer'
export type SizeType = 'footwear' | 'clothing' | 'bags' | 'universal'

// Supabase tipovi rade samo s `type`, a ne s `interface`.
export type FaqItem = { question: string; answer: string }

export type Category = {
  id: string
  parent_id: string | null
  name: string
  slug: string
  description: string | null
  // SEO (migracija 0031). U tekstu se može upisati {godina}.
  meta_title: string | null
  meta_description: string | null
  seo_text: string | null
  faq: FaqItem[]
  sort_order: number
  is_active: boolean
  created_at: string
  updated_at: string
}

export type CampaignKind = 'permanent' | 'temporary'

// Trajna kampanja nema datume, a privremena ima početak i kraj.
export type Campaign = {
  id: string
  name: string
  kind: CampaignKind
  discount_percent: number
  starts_at: string | null
  ends_at: string | null
  is_paused: boolean
  created_at: string
  updated_at: string
}

export type WeekDay = 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday' | 'Sunday'

export type OpeningHoursDay = { day: WeekDay; closed: boolean; opens: string; closes: string }

export type OrderChannel = 'whatsapp' | 'web'

// Postavke trgovine, jedan redak (migracija 0029).
export type StoreSettings = {
  id: boolean
  phone: string
  whatsapp: string
  viber: string
  email: string
  instagram_url: string
  facebook_url: string
  // Stupac postoji u bazi (migracija 0029), ali se ne koristi: TikToka nema.
  tiktok_url: string
  opening_hours: OpeningHoursDay[]
  shipping_price: number
  free_shipping_above: number
  announcement_enabled: boolean
  announcement_text: string
  // Kako kupac naručuje iz košarice (migracija 0035).
  order_channel: OrderChannel
  updated_at: string
  updated_by_email: string | null
}

export type StoreSettingsInput = Omit<StoreSettings, 'id' | 'updated_at' | 'updated_by_email'>

// Odbrojavanje do akcije na webu (migracija 0032). Samo prikaz, bez sniženja.
export type Countdown = {
  id: string
  title: string
  message: string
  link: string | null
  starts_at: string
  ends_at: string
  is_enabled: boolean
  created_at: string
  updated_at: string
}

export type CountdownInput = Pick<Countdown, 'title' | 'message' | 'link' | 'starts_at' | 'ends_at' | 'is_enabled'>

// Akcijska stranica, npr. /black-friday (migracije 0033 i 0034). Proizvode, postotke i datume daju njezine kampanje (promo_page_campaigns).
export type PromoPage = {
  id: string
  slug: string
  title: string
  intro: string
  nav_label: string
  meta_title: string | null
  meta_description: string | null
  off_text: string
  faq: FaqItem[]
  is_active: boolean
  // Proizvodi se na stranicu dodaju pojedinačno (products.promo_page_id) i dok je uključena prikazuju samo na njoj.
  is_exclusive: boolean
  updated_at: string
}

export type PromoPageInput = Omit<PromoPage, 'id' | 'slug' | 'updated_at'>

// Stranica s id-evima svojih kampanja, za admin.
export type PromoPageWithCampaigns = PromoPage & { campaign_ids: string[] }

export type PromoPageState = 'live' | 'upcoming' | 'off'

// Što kupci dobivaju iz shop_promo_page.
export type ShopPromoPage = Pick<PromoPage, 'slug' | 'title' | 'intro' | 'nav_label' | 'meta_title' | 'meta_description' | 'off_text' | 'faq' | 'is_exclusive'> & {
  state: PromoPageState
  starts_at: string | null
  ends_at: string | null
  // Postoci s proizvodima, od najvećeg.
  groups: { discount_percent: number; product_ids: string[] }[]
}

// Članak bloga (migracija 0037). Tekst: prazan red je odlomak, "## " je podnaslov.
export type BlogPost = {
  id: string
  slug: string
  title: string
  excerpt: string
  body: string
  cover_path: string | null
  cover_alt: string
  meta_title: string | null
  meta_description: string | null
  faq: FaqItem[]
  is_published: boolean
  published_at: string | null
  created_at: string
  updated_at: string
}

export type BlogPostInput = Omit<BlogPost, 'id' | 'published_at' | 'created_at' | 'updated_at'>

export type BulkProductChanges = { is_visible: boolean } | { store_only: boolean } | { campaign_id: string | null }

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
  // Sniženje dolazi iz kampanje: baza upisuje postotak dok je kampanja aktivna i sama računa sniženu cijenu.
  campaign_id: string | null
  discount_percent: number | null
  sale_price: number | null
  // Akcijska stranica na koju je proizvod pojedinačno dodan (Čišćenje zaliha, migracija 0039).
  promo_page_id: string | null
  // Baza ga upisuje dok je ta stranica uključena: tada je proizvod samo na njoj, a ne u ostatku trgovine.
  promo_only: boolean
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
  | 'size_type' | 'price' | 'campaign_id' | 'dress_length' | 'heel_height' | 'weight_grams' | 'is_visible' | 'store_only' | 'meta_title' | 'meta_description'
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
  // Promo kod iz košarice. Baza ga ponovno provjerava pri slanju.
  promo_code: string | null
}

export type NewsletterSubscriber = {
  id: string
  email: string
  created_at: string
  // Osobni token za poveznicu za odjavu u e-mailu (migracija 0030).
  unsubscribe_token: string
  // Odjavljeni ostaju na popisu, kako ponovnom prijavom ne bi dobili novi kod.
  unsubscribed_at: string | null
}

export type PromoCodeKind = 'newsletter' | 'manual'

// Kod pretplatnika (newsletter) vrijedi jednom 15 dana. Vlastiti kod (manual) vrijedi od-do, bez ograničenja broja upotreba.
export type PromoCode = {
  id: string
  code: string
  kind: PromoCodeKind
  name: string | null
  discount_percent: number
  starts_at: string
  ends_at: string
  max_uses: number | null
  used_count: number
  is_active: boolean
  subscriber_id: string | null
  created_at: string
}

export type InquiryStatus = 'new' | 'in_progress' | 'sold' | 'cancelled'

export type DashboardBasic = {
  orders: { new: number; in_progress: number; today: number }
  products: { visible: number; hidden: number; archived: number; on_sale: number }
  sold_out_colors: number
  // Rasprodane boje (sve veličine na nuli), najviše 30.
  sold_out: { product_id: string; name: string; sku: string; color: string }[]
  low_stock: { product_id: string; name: string; sku: string; color: string; size: string; quantity: number }[]
  low_stock_total: number
  subscribers: number
}

// Zbroj komada na stanju po glavnoj kategoriji proizvoda i veličini.
export type StockBySizeRow = { category_id: string; size: string; quantity: number }

export type AnalyticsBucket = 'day' | 'week' | 'month'

// Redak poretka: proizvod, boja, veličina ili kategorija.
export type AnalyticsRankRow = { name: string; sku?: string; quantity: number; revenue: number }

export type SalesAnalytics = {
  from: string
  to: string
  bucket: AnalyticsBucket
  kpi: {
    revenue: number
    orders: number
    average_order: number
    shipping: number
    promo_discount: number
    items: number
    sale_savings: number
    sale_revenue: number
    goods_revenue: number
  }
  previous: { revenue: number; orders: number; inquiries: number }
  statuses: Partial<Record<InquiryStatus, number>>
  // inquiries su svi novi upiti u razdoblju, a orders i revenue samo prodani.
  trend: { bucket: string; revenue: number; orders: number; inquiries: number }[]
  products: AnalyticsRankRow[]
  colors: AnalyticsRankRow[]
  sizes: AnalyticsRankRow[]
  categories: AnalyticsRankRow[]
  promo_codes: { code: string; kind: PromoCodeKind; orders: number; discount: number }[]
  newsletter: { total: number; new: number; codes_used: number }
}

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
  // Sveukupno (total) = ukupno za proizvode (subtotal) - promo popust + poštarina.
  subtotal: number
  shipping: number
  total: number
  promo_code_id: string | null
  promo_code: string | null
  promo_discount: number
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
      promo_pages: {
        Row: PromoPage
        Insert: PromoPageInput & Pick<PromoPage, 'slug'>
        Update: Partial<PromoPageInput>
        Relationships: []
      }
      promo_page_campaigns: {
        Row: { page_id: string; campaign_id: string }
        Insert: { page_id: string; campaign_id: string }
        Update: never
        Relationships: [
          { foreignKeyName: 'promo_page_campaigns_page_id_fkey'; columns: ['page_id']; isOneToOne: false; referencedRelation: 'promo_pages'; referencedColumns: ['id'] },
        ]
      }
      blog_posts: {
        Row: BlogPost
        Insert: BlogPostInput
        Update: Partial<BlogPostInput>
        Relationships: []
      }
      countdowns: {
        Row: Countdown
        Insert: CountdownInput
        Update: Partial<CountdownInput>
        Relationships: []
      }
      store_settings: {
        Row: StoreSettings
        Insert: never
        Update: Partial<StoreSettingsInput>
        Relationships: []
      }
      campaigns: {
        Row: Campaign
        Insert: Pick<Campaign, 'name' | 'kind' | 'discount_percent'> & Partial<Campaign>
        Update: Partial<Campaign>
        Relationships: []
      }
      newsletter_subscribers: {
        Row: NewsletterSubscriber
        Insert: never
        Update: never
        Relationships: []
      }
      promo_codes: {
        Row: PromoCode
        Insert: Pick<PromoCode, 'code' | 'kind' | 'discount_percent' | 'starts_at' | 'ends_at'> & Partial<PromoCode>
        Update: Partial<PromoCode>
        Relationships: [Relationship & {
          foreignKeyName: 'promo_codes_subscriber_id_fkey'
          columns: ['subscriber_id']
          referencedRelation: 'newsletter_subscribers'
          referencedColumns: ['id']
        }]
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
      admin_stock_by_size: { Args: Record<string, never>; Returns: StockBySizeRow[] }
      admin_dashboard_basic: { Args: Record<string, never>; Returns: DashboardBasic }
      admin_sales_analytics: { Args: { p_from: string | null; p_to: string | null; p_bucket: AnalyticsBucket }; Returns: SalesAnalytics }
      shop_check_promo: { Args: { p_code: string }; Returns: { code: string; percent: number } }
      newsletter_unsubscribe: { Args: { p_token: string }; Returns: undefined }
      shop_promo_page: { Args: { p_slug: string }; Returns: ShopPromoPage | null }
      shop_product_redirect: { Args: { p_color_slug: string }; Returns: { status: 'archived' | 'not_archived' | 'unknown'; category_slug?: string | null } }
      save_promo_page: { Args: { p_id: string; p_page: PromoPageInput; p_campaign_ids: string[] }; Returns: undefined }
      newsletter_unsubscribe_email: { Args: { p_email: string }; Returns: undefined }
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
      set_promo_page_products: { Args: { p_slug: string; p_ids: string[]; p_on: boolean }; Returns: number }
      bulk_update_products: {
        Args: { p_ids: string[]; p_changes: BulkProductChanges }
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

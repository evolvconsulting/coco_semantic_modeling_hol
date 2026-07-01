const DEALER_IMAGES: Record<string, string> = {
  D4471: "/images/toyota.jpg",
};

export function dealerImage(dealerId: string): string | undefined {
  return DEALER_IMAGES[dealerId];
}

import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "بيكو | لوحة الإدارة والمكاتب",
  description: "لوحة موحدة لإدارة منصة بيكو",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="ar" dir="rtl">
      <body>{children}</body>
    </html>
  );
}


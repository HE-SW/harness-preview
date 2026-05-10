import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "루키스의 그림판",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ko">
      <body className="bg-[#0a0a0a] text-white antialiased">{children}</body>
    </html>
  );
}

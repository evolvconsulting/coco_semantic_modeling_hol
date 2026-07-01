import "./WhyBlock.css";

interface WhyBlockProps {
  children: string;
}

export function WhyBlock({ children }: WhyBlockProps) {
  return <p className="why-block">{children}</p>;
}

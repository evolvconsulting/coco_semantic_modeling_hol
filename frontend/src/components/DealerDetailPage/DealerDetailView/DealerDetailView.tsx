import { useRef, useState, type CSSProperties } from "react";
import type { Dealer } from "../../../api";
import { healthOf, scoreOf } from "../../../health";
import { HEALTH_COLORS } from "../../../colors";
import { useDealerDetail } from "../../../hooks/useDealerDetail";
import { dealerImage } from "../shared/dealerImage";
import { DetailSidebar } from "../DetailSidebar/DetailSidebar";
import { CreditMixSection } from "../sections/CreditMixSection";
import { FundingSection } from "../sections/FundingSection";
import { ExceptionsSection } from "../sections/ExceptionsSection";
import { ServicingSection } from "../sections/ServicingSection";
import "./DealerDetailView.css";

interface DealerDetailViewProps {
  dealer: Dealer;
  leaving: boolean;
  onBack: () => void;
}

export function DealerDetailView({
  dealer,
  leaving,
  onBack,
}: DealerDetailViewProps) {
  const health = healthOf(dealer);
  const latest = dealer.performance[dealer.performance.length - 1];
  const prior = dealer.performance[dealer.performance.length - 2] ?? latest;
  const score = Math.round(scoreOf(latest) * 100);
  const scoreDelta = score - Math.round(scoreOf(prior) * 100);
  const style = { "--health-accent": HEALTH_COLORS[health] } as CSSProperties;
  const { detail, loading, error } = useDealerDetail(dealer.id);

  const contentRef = useRef<HTMLElement>(null);
  const [highlight, setHighlight] = useState<{ top: number; height: number } | null>(
    null,
  );
  const [activeIndex, setActiveIndex] = useState<number | null>(null);

  const handleHover = (index: number) => (target: HTMLElement | null) => {
    if (!target || !contentRef.current) {
      setHighlight(null);
      setActiveIndex(null);
      return;
    }
    const containerRect = contentRef.current.getBoundingClientRect();
    const targetRect = target.getBoundingClientRect();
    setHighlight({
      top: targetRect.top - containerRect.top + contentRef.current.scrollTop,
      height: targetRect.height,
    });
    setActiveIndex(index);
  };

  return (
    <div
      className={`detail-view${leaving ? " detail-view--leaving" : ""}`}
      style={style}
    >
      <DetailSidebar
        name={dealer.name}
        meta={`Tier ${dealer.tier} · ${dealer.territory}`}
        health={health}
        score={score}
        scoreDelta={scoreDelta}
        image={dealerImage(dealer.id)}
        onBack={onBack}
      />
      <main className="detail-content" ref={contentRef}>
        {error && <p className="detail-status">{error}</p>}
        {loading && <p className="detail-status">Loading…</p>}
        {detail && (
          <>
            <div
              className="row-highlight"
              style={{
                opacity: highlight ? 1 : 0,
                transform: `translateY(${highlight?.top ?? 0}px)`,
                height: highlight?.height,
              }}
              aria-hidden
            />
            <CreditMixSection
              data={detail.creditMix}
              index={0}
              active={activeIndex === 0}
              onHover={handleHover(0)}
            />
            <FundingSection
              data={detail.funding}
              index={1}
              active={activeIndex === 1}
              onHover={handleHover(1)}
            />
            <ExceptionsSection
              data={detail.exceptions}
              index={2}
              active={activeIndex === 2}
              onHover={handleHover(2)}
            />
            <ServicingSection
              data={detail.servicing}
              index={3}
              active={activeIndex === 3}
              onHover={handleHover(3)}
            />
          </>
        )}
      </main>
    </div>
  );
}

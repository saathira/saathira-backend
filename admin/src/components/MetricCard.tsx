import React from 'react';
import { LucideIcon } from 'lucide-react';

interface MetricCardProps {
  label: string;
  value: string | number;
  subtext?: string;
  icon: LucideIcon;
  iconColor?: string;
  trend?: string;
}

export const MetricCard: React.FC<MetricCardProps> = ({
  label,
  value,
  subtext,
  icon: Icon,
  iconColor = 'text-brand-primary',
  trend,
}) => {
  return (
    <div className="bg-brand-card p-5 rounded-2xl border border-brand-border flex flex-col justify-between hover:border-brand-primary/40 transition-all duration-200 shadow-sm">
      <div className="flex items-start justify-between">
        <div>
          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">{label}</span>
          <h3 className="text-2xl font-bold text-white mt-1.5">{value}</h3>
        </div>
        <div className={`p-2.5 rounded-xl bg-white/[0.04] border border-white/[0.06] ${iconColor}`}>
          <Icon className="w-5 h-5" />
        </div>
      </div>
      {(subtext || trend) && (
        <div className="mt-3 flex items-center justify-between text-xs text-slate-400 border-t border-white/[0.04] pt-2.5">
          <span>{subtext}</span>
          {trend && <span className="text-emerald-400 font-semibold">{trend}</span>}
        </div>
      )}
    </div>
  );
};

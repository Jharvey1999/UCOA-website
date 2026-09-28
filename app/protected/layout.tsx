import { EnvVarWarning } from "@/components/env-var-warning";
import { AuthButton } from "@/components/auth-button";
import { ThemeSwitcher } from "@/components/theme-switcher";
import { hasEnvVars } from "@/lib/utils";
import { Mountain } from "lucide-react";
import Link from "next/link";
import { Suspense } from "react";

export default function ProtectedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <main className="min-h-screen bg-[#f3f0e8] text-[#19352d]">
      <header className="border-b border-[#c9d6d0] bg-[#f8f6f0]">
        <div className="mx-auto flex w-full max-w-7xl items-center justify-between gap-6 px-5 py-5 sm:px-8 lg:px-12">
          <Link
            className="flex items-center gap-3 text-sm font-bold uppercase tracking-[0.16em]"
            href="/"
          >
            <span className="flex size-9 items-center justify-center bg-[#19352d] text-[#f3f0e8]">
              <Mountain aria-hidden="true" className="size-5" />
            </span>
            UCOA
          </Link>
          <nav aria-label="Member navigation" className="flex items-center gap-4 text-sm">
            <Link className="text-[#557268] transition-colors hover:text-[#19352d]" href="/events">
              Events
            </Link>
            <Link className="text-[#557268] transition-colors hover:text-[#19352d]" href="/protected/waivers">
              Waivers
            </Link>
            {!hasEnvVars ? (
              <EnvVarWarning />
            ) : (
              <Suspense>
                <AuthButton />
              </Suspense>
            )}
          </nav>
        </div>
      </header>
      <div className="mx-auto flex w-full max-w-7xl flex-col px-5 sm:px-8 lg:px-12">
        {children}
      </div>
      <footer className="mt-16 border-t border-[#c9d6d0] px-5 py-8 sm:px-8 lg:px-12">
        <div className="mx-auto flex w-full max-w-7xl items-center justify-between gap-4 text-xs uppercase tracking-[0.12em] text-[#71847b]">
          <span>UCOA member portal</span>
          <ThemeSwitcher />
        </div>
      </footer>
    </main>
  );
}

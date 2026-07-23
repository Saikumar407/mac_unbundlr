import { motion } from "framer-motion";
import Header from "@/components/landing/Header";
import Hero from "@/components/landing/Hero";
import ProblemComparison from "@/components/landing/ProblemComparison";
import FeatureBento from "@/components/landing/FeatureBento";
import InteractiveDemo from "@/components/landing/InteractiveDemo";
import Architecture from "@/components/landing/Architecture";
import Downloads from "@/components/landing/Downloads";
import Roadmap from "@/components/landing/Roadmap";
import Security from "@/components/landing/Security";
import Faq from "@/components/landing/Faq";
import Footer from "@/components/landing/Footer";

export default function Landing() {
  return (
    <div className="relative min-h-screen overflow-x-hidden">
      <Header />
      <main className="relative">
        <Hero />
        <ProblemComparison />
        <FeatureBento />
        <InteractiveDemo />
        <Architecture />
        <Downloads />
        <Roadmap />
        <Security />
        <Faq />
      </main>
      <Footer />
    </div>
  );
}

import FastAPIPCAPlot from "@/components/FastAPIPCAPlot"
import TechExplainer from "@/components/TechExplainer"

export default function PCAPage() {
  return (
    <div className="container mx-auto">
      <FastAPIPCAPlot />
      <div className="p-6">
        <TechExplainer type="pca" />
      </div>
    </div>
  )
}
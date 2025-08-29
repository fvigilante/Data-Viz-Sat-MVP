import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

export default function PCAPage() {
  return (
    <div className="p-6">
      <Card>
        <CardHeader>
          <CardTitle>PCA Analysis</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-center h-96 text-muted-foreground">
            <div className="text-center">
              <h3 className="text-lg font-semibold mb-2">Coming Soon</h3>
              <p>Principal Component Analysis visualization will be available in a future update.</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

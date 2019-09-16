namespace TankyReloaded
{
    public static class StageObjectMixin 
    {
        public static bool Collides(this IStageObject self, IStageObject another)
        {
            return self.Bounds.Intersects(another.Bounds);
        }
    }
}
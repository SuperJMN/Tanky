namespace SuperJMN.MonoGame
{
    public static class StageObjectMixin 
    {
        public static bool Collides(this IStageObject self, IStageObject another)
        {
            return self.Bounds.Intersects(another.Bounds);
        }
        
        public static bool IsOutOfBounds(this IStageObject self)
        {
            return !self.Stage.GetBounds().Intersects(self.Bounds);
        }
    }
}
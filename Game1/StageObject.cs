using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace TankyReloaded
{
    public abstract class StageObject : IStageObject
    {
        public abstract void Draw(SpriteBatch spriteBatch);
        
        public double Left { get; set; }
        public double Top { get; set; }
        public double Width { get; set; }
        public double Height { get; set; }
        public Rectangle Bounds => new Rectangle((int) Left, (int) Top, (int) Width, (int) Height);
        public IStage Stage { get; set; }
        public abstract void LoadContent(ContentManager content);
        public abstract void Update(GameTime gameTime);
        public virtual void CollideWith(IStageObject other){ }
    }
}